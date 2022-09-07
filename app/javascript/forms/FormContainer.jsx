import { Container, Navbar, NavbarBrand } from "reactstrap";
import React from "react";

export default ({ name, children }) => {
  return (
    <div
      style={{
        flex: "1 1 100%",
        height: "100%",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <Navbar color="light" light expand="md">
        <Container>
          <NavbarBrand href="/v1/dashboard">{name}</NavbarBrand>
        </Container>
      </Navbar>
      {children}
    </div>
  );
};
