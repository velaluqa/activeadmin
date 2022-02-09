import { Form } from "@formio/react";
import { Nav, NavItem, NavLink } from "reactstrap";
import React from "react";
import ReactJson from "react-json-view";
import ReactJsonViewCompare from "react-json-view-compare";

import useStickyState from "../hooks/useStickyState";

export default ({ configuration, previousConfiguration }) => {
  const [viewType, setViewType] = useStickyState(
    "json",
    "configurationPreviewViewType"
  );

  const previousJson =
    previousConfiguration.payload && JSON.parse(previousConfiguration.payload);
  const json = JSON.parse(configuration.payload);

  return (
    <div>
      <Nav tabs>
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
        <NavItem>
          <NavLink
            active={viewType === "diff"}
            onClick={() => setViewType("diff")}
            href="#"
          >
            Diff
          </NavLink>
        </NavItem>
      </Nav>

      {viewType === "json" ? (
        <div style={{ padding: 8 }}>
          <ReactJson src={json} style={{ fontSize: "0.8em" }} />
        </div>
      ) : viewType === "raw" ? (
        <div style={{ padding: 8 }}>
          <pre>{JSON.stringify(json, null, 2)}</pre>
        </div>
      ) : viewType === "diff" ? (
        <div style={{ padding: 8 }}>
          <ReactJsonViewCompare oldData={previousJson} newData={json} />
        </div>
      ) : (
        "Unknown"
      )}
    </div>
  );
};
