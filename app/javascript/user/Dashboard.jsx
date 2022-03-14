import "../app/general.scss";

import {
  Alert,
  Button,
  Card,
  CardBody,
  CardSubtitle,
  CardText,
  CardTitle,
  Col,
  Container,
  Row,
  Table,
} from "reactstrap";
import React from "react";
import useQueryString from "use-query-string";

import { filter } from "lodash";

import MessageModal from "../forms/MessageModal";
import updateHistory from "../functions/updateHistory";

const signedCount = (answers) =>
  filter(answers, ({ submittedAt }) => !!submittedAt).length;

export default ({ formSessions, formAnswers }) => {
  const [query, setQuery] = useQueryString(window.location, updateHistory, {
    parseBooleans: true,
  });

  const { message } = query;

  const openForm = (id) => {
    window.location = `/v1/form_answers/${id}/edit?referrer=dashboard`;
  };

  return (
    <Container style={{ marginTop: "64px" }}>
      {formAnswers.length == 0 && formSessions.length == 0 && (
        <Alert>
          <h4 className="alert-heading">Well done!</h4>
          <p>There are no open tasks assigned to you!</p>
        </Alert>
      )}
      <Row>
        <Col>
          <Card>
            <CardBody>
              <CardTitle tag="h5">Open Sessions</CardTitle>
              <CardSubtitle className="mb-2 text-muted" tag="h6">
                Sessions contain a sequence of tasks for you to perform.
              </CardSubtitle>
              <CardText>
                <Table borderless>
                  <thead>
                    <tr>
                      <th>#</th>
                      <th>Session Name</th>
                      <th>Tasks</th>
                      <th></th>
                    </tr>
                  </thead>
                  <tbody>
                    {formSessions.map(({ name, answers }, i) => (
                      <tr>
                        <th scope="row">{i + 1}</th>
                        <td>{name}</td>
                        <td>
                          {signedCount(answers)} / {answers.length}
                        </td>
                        <td style={{ textAlign: "right" }}>
                          <Button color="primary" size="sm">
                            Start Session
                          </Button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </Table>
              </CardText>
            </CardBody>
          </Card>
        </Col>
        <Col>
          <Card>
            <CardBody>
              <CardTitle tag="h5">Open Tasks</CardTitle>
              <CardSubtitle className="mb-2 text-muted" tag="h6">
                These tasks have been assigned to you or can be claimed by
                anyone.
              </CardSubtitle>
              <CardText>
                {formAnswers.length > 0 ? (
                  <Table borderless>
                    <thead>
                      <tr>
                        <th>#</th>
                        <th>Name</th>
                        <th>Resource</th>
                        <th></th>
                      </tr>
                    </thead>
                    <tbody>
                      {formAnswers.map(
                        ({ id, formDefinition, formAnswerResources }, i) => (
                          <tr>
                            <th scope="row">{i + 1}</th>
                            <td>{formDefinition.name}</td>
                            <td>
                              {formAnswerResources.length == 0 ? (
                                <span style={{ opacity: 0.5 }}>None</span>
                              ) : (
                                `${formAnswerResources.length} ${formAnswerResources[0].resourceType}`
                              )}
                            </td>
                            <td style={{ textAlign: "right" }}>
                              <Button
                                color="primary"
                                size="sm"
                                onClick={() => openForm(id)}
                              >
                                Open
                              </Button>
                            </td>
                          </tr>
                        )
                      )}
                    </tbody>
                  </Table>
                ) : (
                  <div
                    style={{
                      textAlign: "center",
                      padding: "32px 16px",
                      color: "#ccc",
                    }}
                  >
                    Currently no tasks assigned
                  </div>
                )}
              </CardText>
            </CardBody>
          </Card>
        </Col>
      </Row>
      <MessageModal
        message={message}
        hide={() => setQuery({ message: undefined })}
      />
    </Container>
  );
};
