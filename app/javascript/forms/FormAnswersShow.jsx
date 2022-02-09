import { Button, Modal, ModalBody, ModalFooter } from "reactstrap";
import { Form } from "@formio/react";
import React from "react";
import useQueryString from "use-query-string";

import Signature from "./Signature";
import updateHistory from "../functions/updateHistory";

export default ({ formAnswer, signatureUser, formDefinition, formLayout }) => {
  console.log(formAnswer, signatureUser);

  const { answers } = formAnswer;
  const [query, setQuery] = useQueryString(window.location, updateHistory, {
    parseBooleans: true,
  });

  const showSuccessMessage = query.message === "success";
  const hideSuccessMessage = () => {
    setQuery({ message: undefined });
  };

  return (
    <div className="form-container">
      <link rel="preconnect" href="https://fonts.googleapis.com" />
      <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
      <link
        href="https://fonts.googleapis.com/css2?family=Caveat&display=swap"
        rel="stylesheet"
      />
      <h1>{formDefinition.name}</h1>
      <Form
        submission={{ data: answers }}
        form={formLayout}
        options={{ readOnly: true }}
      />
      <Modal
        isOpen={showSuccessMessage}
        size="sm"
        centered
        toggle={hideSuccessMessage}
      >
        <ModalBody>Data has been signed and saved successfully!</ModalBody>
        <ModalFooter>
          <Button color="primary" onClick={hideSuccessMessage}>
            Ok
          </Button>
        </ModalFooter>
      </Modal>
      <Signature
        formAnswerId={formAnswer.id}
        fullname={signatureUser.name}
        username={signatureUser.username}
        signedAt={formAnswer.submittedAt}
        signature={formAnswer.answersSignature}
        reason={formAnswer.signingReason}
      />
    </div>
  );
};
