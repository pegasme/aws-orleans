import React from "react";

import { useState } from "react";

const CreateUser = () => {
  const [name, setName] = useState("");

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Handle user creation logic here
    alert(`User created: ${name}`);
  };

  return (
    <form onSubmit={handleSubmit}>
      <label htmlFor="name">Name:</label>
      <input
        id="name"
        type="text"
        value={name}
        onChange={e => setName(e.target.value)}
        required
      />
      <button type="submit">Create User</button>
    </form>
  );
};

export default CreateUser;