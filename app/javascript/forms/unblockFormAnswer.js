export default ({ formAnswerId }) => {
  return new Promise((resolve, reject) => {
    fetch(`/v1/form_answers/${formAnswerId}/unblock`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        "X-CSRF-Token": $("meta[name=csrf-token]").attr("content"),
      },
    })
      .then((response) => response.json())
      .then(({ status, ...response }) => {
        if (status == 401) {
          reject("Unauthorized");
        }
        if (status == 200) resolve(response);
      });
  });
};
