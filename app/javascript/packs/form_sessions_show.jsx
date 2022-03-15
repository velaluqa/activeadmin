import React from "react";
import ReactDOM from "react-dom";

import FormSessionShow from "../forms/FormSessionShow";

document.addEventListener("DOMContentLoaded", () => {
  ReactDOM.render(
    <FormSessionShow {...window.componentProps} />,
    document.getElementById("app")
  );
});
