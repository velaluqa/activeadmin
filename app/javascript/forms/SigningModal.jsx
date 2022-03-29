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
  data,
  signatureName,
  onSign,
}) => {
  console.log(onSign);

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

    console.log("handle on sign ", onSign);

    if (onSign) {
      onSign({ answers: data, signingPassword })
        .then((error) => {
          setLoading(false);
        })
        .catch((error) => {
          setLoading(false);
          setError(error);
          setShowError(true);
        });
    }
  };

  const triggerSubmit = () => {
    formRef.current.dispatchEvent(
      new Event("submit", { cancelable: true, bubbles: true })
    );
  };

  return (
    <>
      <Modal isOpen={isOpen} toggle={loading ? false : onClose} centered>
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
                disabled={loading}
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
        <ModalFooter style={{ whiteSpace: "nowrap" }}>
          <Button color="primary" onClick={triggerSubmit} disabled={loading}>
            Sign as {signatureName}
          </Button>{" "}
          <Button onClick={onClose} disabled={loading}>
            Cancel
          </Button>
        </ModalFooter>
      </Modal>
    </>
  );
};
