<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceApplicationController" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceConstants" %>

<c:set var="applicationEndpoint" value="<%=SpaceApplicationController.PATH%>"/>
<c:set var="paramAction" value="<%=SpaceConstants.PARAM_ACTION%>"/>
<c:set var="paramProjectId" value="<%=SpaceConstants.PARAM_PROJECT_ID%>"/>
<c:set var="paramProjectConnectionId" value="<%=SpaceConstants.PARAM_PROJECT_CONNECTION_ID%>"/>
<c:set var="actionIssueScopedProjectToken" value="<%=SpaceConstants.ACTION_ISSUE_SCOPED_PROJECT_TOKEN%>"/>

<script type="text/javascript">
  BS.SpaceTokenService = {
    issueScopedProjectToken(projectId, projectConnectionId, callbacks) {
      const that = this;

      BS.ajaxRequest(window['base_uri'] + '${applicationEndpoint}', {
        method: 'post',
        parameters: {
          '${paramAction}': '${actionIssueScopedProjectToken}',
          '${paramProjectId}': projectId,
          '${paramProjectConnectionId}': projectConnectionId
        },
        onComplete: function (response) {
          if (response.status >= 400) {
            that.handleError(callbacks.onFailure, response.responseJSON.message);
            return;
          }

          callbacks.onSuccess(response.responseJSON.tokenId);
        }
      });
    },

    handleError(onFailure, errorMessage, status) {
      if (!onFailure) {
        TeamCityAPI.Services.AlertService.addAlert(errorMessage, "error");
      } else {
        onFailure(errorMessage, status);
      }
    }
  };
</script>