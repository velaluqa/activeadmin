import React from "react";
import ReactDOM from "react-dom";

import FormAnswersEdit from "../forms/FormAnswersEdit";

document.addEventListener("DOMContentLoaded", () => {
  ReactDOM.render(
    <FormAnswersEdit {...window.componentProps} />,
    document.getElementById("app")
  );
});
