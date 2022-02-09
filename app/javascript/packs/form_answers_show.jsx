import React from "react";
import ReactDOM from "react-dom";

import FormAnswersShow from "../forms/FormAnswersShow";

document.addEventListener("DOMContentLoaded", () => {
  ReactDOM.render(
    <FormAnswersShow {...window.componentProps} />,
    document.getElementById("app")
  );
});
