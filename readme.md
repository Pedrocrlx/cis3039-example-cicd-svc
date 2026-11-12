# Backend Service CI/CD Example

## Project

This project provides Azure Functions for managing products.

### Available Endpoints

- `GET /api/products` - List all products
- `POST /api/products` - Upsert (create or update) a product
- `PUT /api/products` - Upsert (create or update) a product

## CI/CD Features

This project includes a GitHub Actions workflow (`.github/workflows/build.yml`) to build the project. This would act as a Continuous Integration (CI) check to verify the latest code changes (git commit) have not broken the code base.

Make a small code change, `git commit`, `git push` and then observe the GitHub Action running in the GitHub website (within the Actions tab of the code repo).

> There may be other branches in this repo demonstrating additional CI/CD features.

## Local Setup

1. Install dependencies:

```bash
npm install
```

2. Create your local settings file:

Copy the template to create your local development settings:

```bash
cp local.settings.template.json local.settings.json
```

> **Note:** Never commit your `local.settings.json` to source control. The template is safe to share.

3. Build the project:

```bash
npm run build
```

## Local testing with curl

### Start the Function App

```bash
npm start
```

The function app will start on `http://localhost:7071`.

### List Products

Split the VS Code terminal so you can see the output from the localling running app whilst having a new shell prompt to make a test HTTP call:

```bash
curl -i http://localhost:7071/api/products
```

The fake repo initialises with some example data, so expect an array of products.

### Upsert a Product

Using the sample data file (and a new bash terminal):

```bash
curl -i -X POST http://localhost:7071/api/products \
  -H "Content-Type: application/json" \
  -d @samples/product-post.json
```

Repeating the list products call should now show the new item.

## Azure Setup

The `terraform/` directory provisions a new Resource Group, a Standard LRS Storage
Account, a private deployment container, a Linux Flex Consumption plan (FC1), and
an Azure Function App using Functions v4 and Node.js 22, matching CI. HTTPS is
required. CORS is optional and managed through Terraform.

Flex Consumption is the [recommended plan for new serverless Function Apps](https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale).
Terraform manages infrastructure; Azure Functions Core Tools publishes the code.
This setup does not add a GitHub Actions deployment workflow or Application Insights.

### Prerequisites and Azure sign-in

Install Terraform 1.7 or newer (below 2.0), Azure CLI 2.60 or newer, Azure Functions
Core Tools v4 with Flex Consumption support, and Node.js 22 with npm.
Run these commands from the service root:

```bash
az login
az account list --query "[].{Name:name, Subscription:id}" -o table
az account set --subscription <your-subscription-id>
az account show --query id -o tsv
```

Choose a region permitted by your subscription policies **and** available for Flex
Consumption. A school subscription can also restrict SKUs or regional compute quotas.

```bash
az policy assignment list \
  --query "[?contains(name, 'sys.regionrestriction')].parameters.listOfAllowedLocations.value | []" \
  -o tsv

az functionapp list-flexconsumption-locations \
  --query "sort_by(@, &name)[].{Region:name}" -o table
```

An empty policy query does not prove that all regions are allowed; inherited or
custom policies may use other names. The deployment identity needs permission to
create resources and register `Microsoft.Web` and `Microsoft.Storage` providers.

### Configure and provision infrastructure

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edit `terraform/terraform.tfvars` yourself:

- `subscription_id`: the subscription ID returned by `az account show`.
- `location`: an allowed region that supports Flex Consumption, such as `uksouth`.
- `name_prefix`: a unique prefix such as `shopping-lab-ab47`. Use 3–20 lowercase
  letters, digits or hyphens, starting with a letter and ending with a letter or digit.
- `cors_allowed_origins`: keep `[]` for curl-only tests, or set browser origins such
  as `["http://localhost:5173"]`.

The Resource Group is named `<prefix>-rg`, the plan `<prefix>-plan`, the Function
App `<prefix>-func`, and the Storage Account `<prefix-without-hyphens>st`.
Function App and Storage Account names must be globally unique; change the prefix
if either name is taken. This configuration creates new resources. Do not use an
existing resource group name unless you deliberately import it into Terraform first.

```bash
terraform -chdir=terraform init
terraform -chdir=terraform fmt -check
terraform -chdir=terraform validate
terraform -chdir=terraform test
terraform -chdir=terraform plan -out=deployment.tfplan
terraform -chdir=terraform apply deployment.tfplan
```

Review the plan before applying it. Applying creates billable Azure resources.
The Terraform tests use a mocked provider and do not create Azure resources.
The app scales to zero with no always-ready instances, has 2,048 MB per instance,
and allows up to 40 instances. Storage and function execution can incur charges.

State is local for this lab. Keep `terraform.tfstate` and its backups safe: they
contain Storage Account credentials and are required to update or destroy the
resources. State, plan files, provider downloads and local `.tfvars` files are
ignored by Git. Commit `.terraform.lock.hcl` to keep provider versions reproducible.
For shared use or CI, configure an access-controlled remote backend before applying.

### Publish the project

From the service root, install dependencies, build, and publish the compiled code:

```bash
npm ci
npm run build
func azure functionapp publish "$(terraform -chdir=terraform output -raw function_app_name)"
```

Terraform files are excluded from the deployment by `.funcignore`.
A later code change only requires rebuilding and publishing. To change CORS or
other infrastructure settings, edit your Terraform variables and run plan/apply
again instead of changing those settings with Azure CLI.

### Test the deployed endpoints

```bash
PRODUCTS_URL="$(terraform -chdir=terraform output -raw products_url)"
curl --fail-with-body -i "$PRODUCTS_URL"
curl --fail-with-body -i -X POST "$PRODUCTS_URL" \
  -H "Content-Type: application/json" \
  -d @samples/product-post.json
curl --fail-with-body -i -X PUT "$PRODUCTS_URL" \
  -H "Content-Type: application/json" \
  -d @samples/product-post.json
curl --fail-with-body -i "$PRODUCTS_URL"
```

Expect HTTP 200: GET returns a product array, while POST and PUT return the saved
product. The handlers currently allow anonymous access, so no function key is
needed. Allow a short delay after publishing for the app to become ready.

The repository stores products **in memory**, not in Azure Storage. Data can be
lost on restart and can differ between instances. An upsert followed by GET may
reach different instances, so persistence across requests is not guaranteed.

If you configured a frontend origin, check the CORS preflight too:

```bash
curl -i -X OPTIONS "$PRODUCTS_URL" \
  -H "Origin: http://localhost:5173" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type"
```

The response should include `Access-Control-Allow-Origin` for the configured origin.

### Remove lab resources

When testing is finished, review and confirm the destruction of all resources
managed by this configuration:

```bash
terraform -chdir=terraform plan -destroy
terraform -chdir=terraform destroy
```
