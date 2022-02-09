import {
  Button,
  Form,
  FormGroup,
  Input,
  Label,
  Modal,
  ModalBody,
  ModalFooter,
  ModalHeader,
} from "reactstrap";
import React, { useRef, useState } from "react";

export default ({
  isOpen,
  onClose = () => {},
  formId,
  configurationId,
  data,
  setFormAnswerId = () => {},
}) => {
  const formRef = useRef();
  const username = "aandersen";
  const [signingPassword, setSigningPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [showError, setShowError] = useState(false);

  const closeModal = () => {};
  const hideError = () => {
    setShowError(false);
  };

  const onSubmit = (e) => {
    e.preventDefault();

    if (loading) return;

    setLoading(true);
    fetch(`/v1/forms/${formId}/answers`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        "X-CSRF-Token": $("meta[name=csrf-token]").attr("content"),
      },
      body: JSON.stringify({
        form_answer: {
          signing_password: signingPassword,
          configuration_id: configurationId,
          answers: data,
        },
      }),
    })
      .then((response) => response.json())
      .then(({ status, ...rest }) => {
        if (status == 401) {
          setError("Wrong password or corrupt signing key");
          setShowError(true);
        }
        if (status == 200) {
          window.location.replace(
            `/v1/form_answers/${rest.form_answer_id}?message=success`
          );
        }

        setLoading(false);
      });
  };

  const triggerSubmit = () => {
    formRef.current.dispatchEvent(
      new Event("submit", { cancelable: true, bubbles: true })
    );
  };

  return (
    <>
      <Modal
        isOpen={isOpen}
        size="sm"
        toggle={loading ? false : onClose}
        centered
      >
        <ModalHeader toggle={loading ? false : onClose}>
          Sign Results
        </ModalHeader>
        <ModalBody>
          <Form innerRef={formRef} onSubmit={onSubmit}>
            <FormGroup>
              <Label htmlFor="exampleEmail">Password for Signature</Label>
              <Input
                id="signing-password"
                name="password"
                placeholder="Signing Password"
                type="password"
                autoComplete="new-password"
                onChange={(e) => setSigningPassword(e.target.value)}
                value={signingPassword}
              />
            </FormGroup>
          </Form>
          <Modal isOpen={showError} size="sm" toggle={hideError} centered>
            <ModalBody>{error}</ModalBody>
            <ModalFooter>
              <Button color="danger" onClick={hideError}>
                OK
              </Button>
            </ModalFooter>
          </Modal>
        </ModalBody>
        <ModalFooter>
          <Button color="primary" onClick={triggerSubmit} disabled={loading}>
            Sign as {username}
          </Button>{" "}
          <Button onClick={onClose} disabled={loading}>
            Cancel
          </Button>
        </ModalFooter>
      </Modal>
    </>
  );
};
