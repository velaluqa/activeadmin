import React from "react";
import useQueryString from "use-query-string";

import FormAnswerForm from "./FormAnswerForm";
import FormContainer from "./FormContainer";
import saveDraft from "./saveDraft";
import signAndSubmit from "./signAndSubmit";
import unblockFormAnswer from "./unblockFormAnswer";
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

  const {
    id: formAnswerId,
    blockedAt,
    blockingUserId,
    allowSavingDraft,
  } = formAnswer;

  const goBack = (message = null) => {
    if (referrer === "dashboard") {
      if (message) {
        window.location = `/v1/dashboard?message=${message}`;
      } else {
        window.location = `/v1/dashboard`;
      }
    } else {
      window.location = `/v1/form_answers/${formAnswerId}`;
    }
  };

  const signAnswers = ({ answers, signingPassword }) => {
    return signAndSubmit({
      formAnswerId,
      answers,
      signingPassword,
    }).then(() => {
      goBack("submitted_and_signed");
    });
  };

  const saveDraftAnswers = ({ answers }) => {
    return saveDraft({ formAnswerId, answers });
  };

  const unblockForm = () => {
    return unblockFormAnswer({ formAnswerId }).then(() => {
      goBack();
    });
  };

  return (
    <FormContainer name={formDefinition.name}>
      <FormAnswerForm
        currentUser={currentUser}
        value={{ ...formAnswer.answers, ...prefilledFromQuery }}
        layout={formLayout}
        onSign={signAnswers}
        onSaveDraft={saveDraftAnswers}
        onClose={unblockForm}
        readonly={!!blockedAt && blockingUserId != currentUser.id}
        savable={allowSavingDraft}
        signable
      />
    </FormContainer>
  );
};
