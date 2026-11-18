import { describe, it, expect } from 'vitest';
import { createProduct } from "./product";
                

describe("Product creation validation", async () => {
  it("create product with valid params", () => {
      
    const valid_params = {
      id: 'prod-123',
      name: 'Test Product',
      pricePence: 1999,
      description: 'A great test product',
      updatedAt: new Date('2025-01-01'),
    };

    const create_prod = createProduct(valid_params);

    expect(create_prod).toEqual(valid_params);
  });
});