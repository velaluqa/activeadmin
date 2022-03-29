import React from "react";
import useQueryString from "use-query-string";

import FormAnswerForm from "./FormAnswerForm";
import FormContainer from "./FormContainer";
import signAndCreate from "./signAndCreate";
import updateHistory from "../functions/updateHistory";

export default ({ currentUser, formDefinition, formLayout, configuration }) => {
  const [query, setQuery] = useQueryString(window.location, updateHistory, {
    parseBooleans: true,
  });

  const { referrer, ...prefilledFormData } = query;

  const { id: formId } = formDefinition;
  const { id: configurationId } = configuration;

  const signAnswers = ({ answers, signingPassword }) => {
    return signAndCreate({
      formId,
      signingPassword,
      answers,
      configurationId,
    }).then(({ form_answer_id }) => {
      if (referrer === "dashboard") {
        window.location = `/v1/dashboard?message=submitted_and_signed`;
      } else {
        window.location = `/v1/form_answers/${form_answer_id}?message=success`;
      }
    });
  };

  return (
    <FormContainer name={formDefinition.name}>
      <FormAnswerForm
        currentUser={currentUser}
        value={{ ...prefilledFormData }}
        layout={formLayout}
        onSign={signAnswers}
        signable
      />
    </FormContainer>
  );
};
