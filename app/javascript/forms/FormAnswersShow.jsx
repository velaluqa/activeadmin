import { Button, Modal, ModalBody, ModalFooter } from "reactstrap";
import { Form } from "@formio/react";
import React from "react";
import useQueryString from "use-query-string";

import Signature from "./Signature";
import sha1 from "../functions/sha1";
import updateHistory from "../functions/updateHistory";

export default ({ formAnswer, signatureUser, formDefinition, formLayout }) => {
  const { answers } = formAnswer;
  const [query, setQuery] = useQueryString(window.location, updateHistory, {
    parseBooleans: true,
  });
  const { validate } = query || {};

  console.log(signatureUser);

  const showSuccessMessage = query.message === "success";
  const hideSuccessMessage = () => {
    setQuery({ message: undefined });
  };
  const showValidation = query.validate;
  const hideValidation = () => {
    setQuery({ validate: undefined });
  };

  return (
    <div className="form-container" style={{ marginTop: "70px" }}>
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
      <Modal isOpen={showValidation} size="sm" centered toggle={hideValidation}>
        <ModalBody style={{ textAlign: "center" }}>
          {sha1(formAnswer.answersSignature) == query.sigH ? (
            <>
              <svg
                style={{
                  width: "8rem",
                  height: "8rem",
                  marginBottom: 16,
                }}
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  d="M12 22C6.47967 21.9939 2.00606 17.5203 2 12V11.8C2.10993 6.30453 6.63459 1.92796 12.1307 2.00088C17.6268 2.07381 22.0337 6.56889 21.9978 12.0653C21.9619 17.5618 17.4966 21.9989 12 22ZM7.41 11.59L6 13L10 17L18 9L16.59 7.58L10 14.17L7.41 11.59Z"
                  fill="#228822"
                ></path>
              </svg>
              <div>Signature is valid</div>
            </>
          ) : (
            <>
              <svg
                style={{
                  width: "8rem",
                  height: "8rem",
                  marginBottom: 16,
                }}
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  d="M21.2659 20.998H2.73288C2.37562 20.998 2.04551 20.8074 1.86688 20.498C1.68825 20.1886 1.68825 19.8074 1.86688 19.498L11.1329 3.49799C11.3117 3.1891 11.6415 2.9989 11.9984 2.9989C12.3553 2.9989 12.6851 3.1891 12.8639 3.49799L22.1299 19.498C22.3084 19.8072 22.3085 20.1882 22.1301 20.4975C21.9518 20.8069 21.622 20.9976 21.2649 20.998H21.2659ZM10.9999 15.998V17.998H11.9329H11.9979H12.0629H12.9979V15.998H10.9999ZM10.9999 8.99799V13.998H12.9999V8.99799H10.9999Z"
                  fill="#882222"
                ></path>
              </svg>

              <div>Error validating signature!</div>
            </>
          )}
        </ModalBody>
        <ModalFooter>
          <Button color="primary" onClick={hideValidation}>
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
