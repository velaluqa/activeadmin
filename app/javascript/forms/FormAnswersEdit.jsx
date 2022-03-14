import React from "react";
import useQueryString from "use-query-string";

import FormAnswerForm from "./FormAnswerForm";
import FormContainer from "./FormContainer";
import signAndSubmit from "./signAndSubmit";
import updateHistory from "../functions/updateHistory";

export default ({
  formAnswer,
  currentUser,
  formDefinition,
  configuration,
  formLayout,
}) => {
  const [query, setQuery] = useQueryString(window.location, updateHistory, {
    parseBooleans: true,
  });

  const { referrer, ...prefilledFromQuery } = query;

  if (formAnswer.submittedAt) {
    window.location = `/v1/form_answers/${formAnswer.id}`;

    return null;
  }

  const formAnswerId = formAnswer.id;

  const signAnswers = ({ answers, signingPassword }) => {
    return signAndSubmit({
      formAnswerId,
      answers,
      signingPassword,
    }).then(() => {
      if (referrer === "dashboard") {
        window.location = `/v1/dashboard?message=submitted_and_signed`;
      } else {
        window.location = `/v1/form_answers/${formAnswerId}`;
      }
    });
  };

  return (
    <FormContainer name={formDefinition.name}>
      <FormAnswerForm
        currentUser={currentUser}
        value={{ ...formAnswer.answers, ...prefilledFromQuery }}
        layout={formLayout}
        onSign={signAnswers}
        signable
      />
    </FormContainer>
  );
};
