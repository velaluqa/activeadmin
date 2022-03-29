import QRCode from "qrcode.react";
import React from "react";

import sha1 from "../functions/sha1";

export default ({
  formAnswerId,
  fullname,
  username,
  reason,
  signature,
  signedAt,
}) => {
  const link = `${
    window.location.origin
  }/v1/form_answers/${formAnswerId}?sigH=${sha1(signature)}&validate=true`;
  return (
    <div style={{ marginTop: 32, display: "inline-block", maxWidth: "450px" }}>
      <a href={link} style={{ textDecoration: "none", color: "black" }}>
        <div
          style={{
            padding: "0.3rem",
            userSelect: "none",
            borderRadius: "0.20rem",
            border: "1px solid #e5e5e5",
            width: "100%",
            display: "flex",
            flexDirection: "row",
          }}
        >
          <QRCode
            renderAs="canvas"
            size={640}
            value={link}
            style={{ width: 75, height: 75, flex: "0 0 0%" }}
          />
          <div
            style={{
              width: "calc(100% - 75px - 0.3rem)",
              flex: "1 1 100%",
              marginLeft: "0.3rem",
            }}
          >
            <div
              style={{
                textTransform: "uppercase",
                fontWeight: "bold",
                fontSize: "0.5em",
                opacity: 0.3,
              }}
            >
              Signed by
            </div>
            <div
              style={{
                fontFamily: "'Caveat', cursive",
                fontSize: "1.5em",
                borderBottom: "1px solid #000",
              }}
            >
              {fullname}
            </div>
            <div style={{ opacity: 0.3, fontSize: "0.5em", width: "100%" }}>
              <span style={{ fontWeight: "bold" }}>{fullname}</span> at{" "}
              <span style={{ fontWeight: "bold" }}>{signedAt}</span>
              <div>{reason}</div>
              <div
                style={{
                  textOverflow: "ellipsis",
                  overflow: "hidden",
                  whiteSpace: "nowrap",
                  width: "100%",
                }}
              >
                {signature}
              </div>
            </div>
          </div>
        </div>
      </a>
    </div>
  );
};
