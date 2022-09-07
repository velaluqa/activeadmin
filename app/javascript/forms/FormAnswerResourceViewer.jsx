import React from "react";

export default ({ formAnswerId }) => {
  return (
    <div style={{ flex: "1 1 100%" }}>
      <iframe
        style={{ width: "100%", height: "100%" }}
        src={`/v1/form_answers/${formAnswerId}/viewer/all`}
      />
    </div>
  );
};
