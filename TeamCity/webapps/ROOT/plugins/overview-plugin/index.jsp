<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="labels" tagdir="/WEB-INF/tags/labels" %>
<%@ taglib prefix="merge" tagdir="/WEB-INF/tags/merge" %>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop"%>
<%@ include file="/include.jsp"
%><jsp:useBean id="currentUser" type="jetbrains.buildServer.users.User" scope="request"
/><jsp:useBean id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary" scope="request"
/>
<% request.setAttribute("context", "overview"); %>
<c:set var="isClassicUIUser" value="<%= !WebUtil.withExperimentalOverview(request) %>"/>
<bs:page isSakuraUI="true">
  <jsp:attribute name="head_include">
    <bs:linkScript>
      /js/bs/runningBuilds.js
      /js/bs/buildType.js
      /js/bs/labels.js
      /js/bs/merge.js
      /js/bs/testGroup.js
      /js/bs/testDetails.js
      /js/bs/chart.js
      /js/bs/agents.js
      /js/bs/changeLogGraph.js
      /js/raphael-min.js
      /plugins/jvm-update/updateAgentJVM.js
    </bs:linkScript>
    <bs:linkCSS>
      /css/filePopup.css
      /css/buildGraph.css
      /css/buildLog/testGraphs.css
      /css/settingsTable.css
      /css/buildTypeSettings.css
      /healthStatus/css/healthStatus.css
    </bs:linkCSS>
    <style type="text/css">
      #bodyWrapper {
        min-width: 1000px;
        padding-bottom: 0;
      }
      #breadcrumbsWrapper {
        display: none;
      }
      #mainContent {
        padding-left: 0;
        padding-right: 0;
      }
      div.fixedWidth {
        margin: 0;
      }
      #react-ui-version {
        display: none; /* it's rendered inside the app instead */
      }
    </style>
    <script>
      ReactUI.setIsSakuraUI();

      window.sessionStorage.removeItem('isTemporaryClassicUISession');
    </script>
  </jsp:attribute>
  <jsp:attribute name="body_include">
  <div id="overview"></div>
  <script>
    <c:choose>
      <c:when test="${isClassicUIUser and empty param.enableSakuraByDefault}">
        ReactUI.redirectToClassicUI();
      </c:when>
      <c:otherwise>
        (function () {
          ReactUI.setRouteAvailabilityResponse(JSON.parse('${routeAvailabilityResponse}'));
          ReactUI.renderOverview('overview');
        })();
      </c:otherwise>
    </c:choose>
  </script>
  <bs:pauseBuildTypeDialog/>
  <bs:promoteBuildDialog />
</jsp:attribute>
</bs:page>
