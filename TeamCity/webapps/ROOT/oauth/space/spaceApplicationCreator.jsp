<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceConstants" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceAccessTokenController" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceApplicationController" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceFeatures" %>

<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>

<c:set var="currentSpaceRootUrl" value="${WebUtil.getRootUrl(pageContext.request)}${SpaceAccessTokenController.PATH}"/>
<c:set var="currentSpaceApplicationUrl" value="${SpaceApplicationController.PATH}"/>
<c:set var="spaceFeatures" value="<%=SpaceFeatures.forScope(project)%>"/>

<script type="application/javascript">
  BS.SpaceApplicationCreator = {
    createApplication: function (createSpaceApplicationId, instanceName, projectId, callback, options) {
      if (this.isValid(instanceName)) {
        this.startWaiting();

        <c:choose>
        <c:when test="${spaceFeatures.useTabForCreateApp()}">
          const win = window.open('', '_blank');
        </c:when>
        <c:otherwise>
          const win = window.open('', '_blank', 'width=1000,height=1000');
        </c:otherwise>
        </c:choose>
        if (!win) {
          // we probably ran right into a popup blocker
          this.onFailure("Could not open window, please allow pop-ups and reload this page.", false);
          return;
        }

        const url = window['base_uri'] + '${currentSpaceApplicationUrl}';
        const params = new Map();
        params.set('${SpaceConstants.PARAM_ACTION}', '${SpaceConstants.ACTION_CREATE_APP}');
        params.set('${SpaceConstants.PARAM_TC_INSTANCE_NAME}', instanceName);
        params.set('${SpaceConstants.PARAM_PROJECT_ID}', projectId);
        params.set('${SpaceConstants.PARAM_CREATE_SPACE_APP_ID}', createSpaceApplicationId);
        params.set('tc-csrf-token', '${sessionScope['tc-csrf-token']}');
        if (options) {
          if (options.connectionDisplayName) {
            params.set('${SpaceConstants.PARAM_CONNECTION_DISPLAY_NAME}', options.connectionDisplayName);
          }
          if (options.organizationUrl) {
            params.set('${SpaceConstants.PARAM_SPACE_ORGANIZATION_URL}', options.organizationUrl);
          }
        }

        this.submitViaForm(win.document, url, params);

        const interval = window.setInterval(() => {
          try {
            if (win == null || win.closed) {
              window.clearInterval(interval);

              this.waitForApplicationCreated(createSpaceApplicationId, callback);
            }
          } catch (e) {
          }
        }, 1000);
      }
    },

    startWaiting: function () {
    },

    stopWaiting: function () {
    },

    onTimeout: function () {
    },

    onFailure: function (message, canTryAgain) {
    },

    waitForApplicationCreated: function (createSpaceApplicationId, callback) {
      const updateUrl = window['base_uri'] + '${currentSpaceApplicationUrl}' +
        '?${SpaceConstants.PARAM_ACTION}=${SpaceConstants.ACTION_GET_APP}' +
        '&${SpaceConstants.PARAM_CREATE_SPACE_APP_ID}=' + createSpaceApplicationId;

      let waiting = true;
      const interval = window.setInterval(() => {
        try {

          BS.ajaxRequest(updateUrl, {
            onComplete: (response) => {
              if (response.responseJSON['applicationCreated']) {
                window.clearInterval(interval);

                callback(response.responseJSON);

                waiting = false;
                this.stopWaiting();
              }
            }
          });
        } catch (e) {
        }
      }, 1000);

      // if we haven't heard back after 5s stop bothering
      window.setTimeout(() => {
        if (waiting) {
          window.clearInterval(interval);
          waiting = false;
          this.stopWaiting();
          this.onTimeout();
        }
      }, 5_000);
    },

    isValid: function (instanceName) {
      const valid = instanceName != null && instanceName.length > 0;
      if (!valid) {
        console.log("instance name '", instanceName, "' is not valid");
      }
      return valid;
    },

    submitViaForm: function (document, url, params) {
      var form = document.createElement('form');
      form.id = 'prepareApplicationForm';
      form.action = url;
      form.method = 'post';
      params.forEach((value, key) => this.addParam(document, form, key, value));

      document.getElementsByTagName('body')[0].appendChild(form);
      form.submit();
    },

    addParam: function (document, form, key, value) {
      const input = document.createElement('input');
      input.type = 'hidden';
      input.name = key;
      input.value = value;
      form.appendChild(input);
    }
  };
</script>