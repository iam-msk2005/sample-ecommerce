import React, { useEffect, useState } from 'react';
import './styles.css';

function App() {
  const [products, setProducts] = useState([]);

  useEffect(() => {
    fetch('/api/products') // Proxy to backend API
      .then((response) => response.json())
      .then((data) => setProducts(data))
      .catch((error) => console.error('Error fetching products:', error));
  }, []);

  return (
    <div className="App">
      <h1>E-Commerce Frontend</h1>
      <ul>
        {products.map((product) => (
          <li key={product.id}>
            {product.name} - ${product.price}
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;