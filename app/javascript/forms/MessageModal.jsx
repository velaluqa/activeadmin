import { Button, Modal, ModalBody, ModalFooter } from "reactstrap";
import React from "react";

export default ({ message, hide }) => {
  return (
    <Modal isOpen={!!message} size="sm" centered toggle={hide}>
      <ModalBody style={{ textAlign: "center" }}>
        {message == "submitted_and_signed" ? (
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
            <div>Form answers were signed and submitted successfully</div>
          </>
        ) : (
          <div>{message}</div>
        )}
      </ModalBody>
      <ModalFooter style={{ textAlign: "center" }}>
        <Button color="primary" onClick={hide}>
          Ok
        </Button>
      </ModalFooter>
    </Modal>
  );
};
