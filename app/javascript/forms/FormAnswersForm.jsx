import { Button, Modal, ModalBody, ModalFooter, ModalHeader } from "reactstrap";
import { Form } from "@formio/react";
import React, { useEffect, useState } from "react";
import useQueryString from "use-query-string";

import SigningModal from "./SigningModal";
import updateHistory from "../functions/updateHistory";

export default ({ formDefinition, formLayout, configuration }) => {
  const [query, setQuery] = useQueryString(window.location, updateHistory, {
    parseBooleans: true,
  });

  const [submitting, setSubmitting] = useState(false);
  const [signing, setSigning] = useState(false);
  const [formData, setFormData] = useState(query || {});
  const [formValid, setFormValid] = useState(false);
  const [dirty, setDirty] = useState(false);

  const { name: formName, id: formId } = formDefinition;
  const configurationId = configuration.id;

  useEffect(() => {
    window.prefilledFormData = query;
  }, [JSON.stringify(query)]);

  const onSubmit = (e) => {
    e.preventDefault();
    setSubmitting(true);
  };

  const onChange = ({ isValid, data }) => {
    setFormData(data);
    setDirty(true);
    setFormValid(isValid);
  };

  return (
    <>
      <div style={{ height: "100%" }}>
        <div
          style={{
            height: "100%",
          }}
        >
          <div className="form-container">
            <h1>{formName}</h1>
            <Form
              formReady={(formio) => {
                formio.nosubmit = true;
                formio.submission = { data: query };
              }}
              onChange={onChange}
              form={formLayout}
            />
          </div>
        </div>
        <div
          style={{
            textAlign: "right",
            position: "fixed",
            width: "100%",
            bottom: 0,
          }}
        >
          <div
            className="form-container"
            style={{ padding: "16px", background: "#efefef" }}
          >
            <Button color="primary" onClick={onSubmit} disabled={!formValid}>
              Submit Answers
            </Button>{" "}
            <Button onClick={() => setSubmitting(false)}>Reset</Button>
          </div>
        </div>
      </div>
      <Modal isOpen={submitting} size="xl" toggle={() => setSubmitting(false)}>
        <ModalHeader toggle={() => setSubmitting(false)}>
          Submit {formName}
        </ModalHeader>
        <ModalBody>
          <Form
            submission={{ data: formData }}
            form={formLayout}
            options={{ readOnly: true }}
          />
          <SigningModal
            data={formData}
            isOpen={signing}
            configurationId={configurationId}
            formId={formId}
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
            Submit & Sign
          </Button>{" "}
          <Button onClick={() => setSubmitting(false)}>Cancel</Button>
        </ModalFooter>
      </Modal>
    </>
  );
};
