import { Container, Navbar, NavbarBrand, NavbarText } from "reactstrap";
import React, { useState } from "react";
import useQueryString from "use-query-string";

import { find, findIndex, some } from "lodash";

import FormAnswerForm from "./FormAnswerForm";
import FormAnswerResourceViewer from "./FormAnswerResourceViewer";
import signAndSubmit from "./signAndSubmit";
import updateHistory from "../functions/updateHistory";

export default (props) => {
  const { currentUser, formSession, formAnswers } = props;

  const [query, setQuery] = useQueryString(window.location, updateHistory, {
    parseBooleans: true,
  });

  const { referrer, ...prefilledFromQuery } = query;

  const firstUnreadSequenceNumber = find(formAnswers, {
    status: "published",
  }).sequenceNumber;
  const [sequenceNumber, setSequenceNumber] = useState(
    firstUnreadSequenceNumber
  );

  const formAnswer = find(formAnswers, { sequenceNumber, status: "published" });
  const formAnswerResources = formAnswer.formAnswerResources;
  const formAnswersIndex = findIndex(formAnswers, {
    sequenceNumber,
    status: "published",
  });
  const formAnswersLength = formAnswers.length;
  const { formLayout, id: formAnswerId } = formAnswer;

  const openNextFormAnswer = () => {
    const nextFormAnswer = find(
      formAnswers,
      { status: "published" },
      formAnswersIndex
    );
  };

  const signAnswers = ({ answers, signingPassword }) => {
    return signAndSubmit({
      formAnswerId,
      answers,
      signingPassword,
    }).then(() => {
      const nextFormAnswer = find(
        formAnswers,
        { status: "published" },
        formAnswersIndex + 1
      );
      // differentiate between all tasks finished and unreadable tasks
      if (nextFormAnswer) {
        console.log(nextFormAnswer);
        setSequenceNumber(nextFormAnswer.sequenceNumber);
      } else {
        if (referrer === "dashboard") {
          window.location = `/v1/dashboard?message=all_session_tasks_finished`;
        } else {
          window.location = `/v1/form_sessions/${formSession.id}`;
        }
      }
    });
  };

  // fetch first form answer and display
  // show step in session in the top nav bar
  // when saving the form answer, step to the next form answer
  // otherwise step to the next
  return (
    <div style={{ display: "flex", height: "100%", flexDirection: "row" }}>
      {some(formAnswerResources, { hasDicom: true }) && (
        <FormAnswerResourceViewer formAnswerId={formAnswerId} />
      )}

      <div
        style={{
          flex: "1 1 100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
        }}
      >
        <Navbar color="light" light expand="md">
          <Container>
            <NavbarBrand href="/v1/dashboard">{formSession.name}</NavbarBrand>
            <NavbarText>
              Task {formAnswersIndex + 1} of {formAnswersLength}
            </NavbarText>
          </Container>
        </Navbar>
        <FormAnswerForm
          key={formAnswer.id}
          currentUser={currentUser}
          value={{ ...formAnswer.answers }}
          layout={formLayout}
          onSign={signAnswers}
          signable
        />
      </div>
    </div>
  );
};
