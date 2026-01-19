BS.IssueDetails = function(elementId, issueId, providerId, projectExternalId) {
  BS.Popup.call(this, elementId, {
    issueId: issueId,
    providerId: providerId,
    projectExternalId: projectExternalId,

    shift: {x : -80},
    zIndex: 200,

    url: window['base_uri'] + "/issueDetailsPopup.html?" + Object.toQueryString({
      issueId: issueId,
      providerId: providerId,
      projectId: projectExternalId
    })
  });
};

_.extend(BS.IssueDetails.prototype, BS.Popup.prototype);