// Run this example by adding <%= javascript_pack_tag 'hello_react' %> to the head of your layout file,
// like app/views/layouts/application.html.erb. All it does is render <div>Hello React</div> at the bottom
// of the page.

import { StickyStateStore } from "../hooks/useStickyState";

import React from "react";
import ReactDOM from "react-dom";
import AdminConfigurationsPreview from "../forms/AdminConfigurationsPreview";

document.addEventListener("DOMContentLoaded", () => {
  ReactDOM.render(
    <StickyStateStore>
      <AdminConfigurationsPreview {...window.componentProps} />
    </StickyStateStore>,
    document.getElementById("admin_configurations_preview")
  );
});
