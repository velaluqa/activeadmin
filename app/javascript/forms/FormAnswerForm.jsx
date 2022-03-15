import {
  Container,
  Button,
  Modal,
  ModalBody,
  ModalFooter,
  ModalHeader,
} from "reactstrap";
import { Form } from "@formio/react";
import React, { useCallback, useEffect, useRef, useState } from "react";
import useQueryString from "use-query-string";

import SigningModal from "./SigningModal";
import updateHistory from "../functions/updateHistory";

export default ({
  value,
  layout,
  currentUser,
  onSaveDraft,
  onSubmit,
  onSign,
  signable = true,
  savable = false,
  extraButtons = null,
  formAnswerId,
}) => {
  const formio = useRef();
  const [query, setQuery] = useQueryString(window.location, updateHistory, {
    parseBooleans: true,
  });

  const [submitting, setSubmitting] = useState(false);
  const [signing, setSigning] = useState(false);
  const [formData, setFormData] = useState(value);
  const [formValid, setFormValid] = useState(false);
  const [dirty, setDirty] = useState(false);

  const handleSubmit = (e) => {
    console.log("handleSubmit", e);
    if (formio.current.checkValidity(null, false, null, true)) {
      setSubmitting(true);
    } else {
      formio.current.submit();
    }
  };

  const onChange = ({ isValid, data }) => {
    console.log("onChange", isValid, data, formAnswerId);
    setFormData(data);
    setDirty(true);
    setFormValid(isValid);
  };

  // useEffect(() => {
  //   console.log("formAnswerId changed", formAnswerId, value);
  //   setSubmitting(false);
  //   setSigning(false);
  //   setFormValid(false);
  //   setDirty(false);
  //   setFormData(value);
  //   if (formio.current) {
  //     formio.current.submission = { data: value };
  //   }
  // }, [formAnswerId, value]);

  return (
    <div style={{ flex: "1 1 100%", display: "flex", flexDirection: "column" }}>
      <Container
        style={{
          flex: "1 1 100%",
          marginTop: 32,
          marginBottom: 32,
          overflow: "auto",
        }}
      >
        <Form
          formReady={(form) => {
            formio.current = form;
            formio.current.nosubmit = true;
            formio.current.submission = { data: value };
          }}
          options={{ highlightErrors: true }}
          onChange={onChange}
          form={layout}
        />
      </Container>
      <div style={{ background: "#efefef" }}>
        <Container style={{ padding: "16px", textAlign: "right" }}>
          {savable && (
            <>
              <Button color="secondary" onClick={() => onSaveDraft(formData)}>
                Save Draft
              </Button>{" "}
            </>
          )}
          <Button color="primary" onClick={handleSubmit} disabled={!formValid}>
            Submit Answers
          </Button>{" "}
          <Button onClick={() => setSubmitting(false)}>Reset</Button>
        </Container>
      </div>
      <Modal isOpen={submitting} size="xl" toggle={() => setSubmitting(false)}>
        <ModalHeader toggle={() => setSubmitting(false)}>Submit</ModalHeader>
        <ModalBody>
          <Form
            submission={{ data: formData }}
            form={layout}
            options={{ readOnly: true }}
          />
          <SigningModal
            data={formData}
            isOpen={signing}
            signatureName={currentUser.name}
            onSign={onSign}
            onClose={() => setSigning(false)}
          />
        </ModalBody>
        <ModalFooter>
          <Button
            color="primary"
            onClick={() => {
              setSigning(true);
            }}
          >
            Sign & Submit
          </Button>{" "}
          <Button onClick={() => setSubmitting(false)}>Cancel</Button>
          {extraButtons}
        </ModalFooter>
      </Modal>
    </div>
  );
};
