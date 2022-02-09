import { Form } from "@formio/react";
import { Nav, NavItem, NavLink } from "reactstrap";
import React from "react";
import ReactJson from "react-json-view";

import useStickyState from "../hooks/useStickyState";

const PdfFrame = ({ formAnswerId }) => {
  const url = `${window.location.origin}/v1/form_answers/${formAnswerId}.pdf`;
  const frameUrl = `${
    window.location.origin
  }/viewer/viewer.html?file=${encodeURIComponent(url)}`;
  return (
    <iframe
      src={frameUrl}
      style={{ width: "100%", height: "800px", border: 0 }}
    />
  );
};

export default ({ formDefinition, formAnswer, configuration }) => {
  const answers = formAnswer.answers;
  const formLayout = JSON.parse(configuration.payload);

  const [viewType, setViewType] = useStickyState(
    "viewer",
    "formAnswersPreviewViewType"
  );

  return (
    <div>
      <Nav tabs>
        <NavItem>
          <NavLink
            active={viewType === "viewer"}
            onClick={() => setViewType("viewer")}
            href="#"
          >
            Viewer
          </NavLink>
        </NavItem>
        <NavItem>
          <NavLink
            active={viewType === "pdf"}
            onClick={() => setViewType("pdf")}
            href="#"
          >
            PDF
          </NavLink>
        </NavItem>
        <NavItem>
          <NavLink
            active={viewType === "json"}
            onClick={() => setViewType("json")}
            href="#"
          >
            JSON
          </NavLink>
        </NavItem>
        <NavItem>
          <NavLink
            active={viewType === "raw"}
            onClick={() => setViewType("raw")}
            href="#"
          >
            Raw
          </NavLink>
        </NavItem>
      </Nav>

      {viewType === "viewer" ? (
        <div style={{ padding: 8 }}>
          <Form
            submission={{ data: answers }}
            form={formLayout}
            options={{ readOnly: true }}
          />
        </div>
      ) : viewType === "pdf" ? (
        <div>
          <PdfFrame formAnswerId={formAnswer.id} />
        </div>
      ) : viewType === "json" ? (
        <div style={{ padding: 8 }}>
          <ReactJson src={formAnswer.answers} style={{ fontSize: "0.8em" }} />
        </div>
      ) : viewType === "raw" ? (
        <div style={{ padding: 8 }}>
          <pre>{JSON.stringify(formAnswer.answers, null, 2)}</pre>
        </div>
      ) : (
        "Unknown"
      )}
    </div>
  );
};
