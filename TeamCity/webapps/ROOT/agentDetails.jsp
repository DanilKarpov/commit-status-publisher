<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<jsp:useBean id="agentDetailInfo" scope="request" type="jetbrains.buildServer.controllers.agent.AgentDetailInfo"/>
<jsp:useBean id="serverSummary" scope="request" type="jetbrains.buildServer.web.openapi.ServerSummary"/>
<jsp:useBean id="realAgentName" scope="request" type="java.lang.String"/>

<%@ include file="include-internal.jsp" %>
<l:defineCurrentTab defaultTab=""/>

<ext:forEachTab placeId="<%=PlaceId.AGENT_DETAILS_TAB%>">
  <c:if test="${empty currentTab and extension.tabId == 'agentSummary'}">
    <c:set var="currentTab" value="agentSummary"/>
  </c:if>
  <c:if test="${empty currentTab and extension.tabId == 'agentTypeSummary'}">
    <c:set var="currentTab" value="agentTypeSummary"/>
  </c:if>
  <c:if test="${currentTab == extension.tabId}">
    <c:set var='currentTabTitle' value="${extension.tabTitle}"/>
  </c:if>
</ext:forEachTab>
<c:set var="pageTitle" value="${currentTabTitle}" scope="request"/>
<bs:page>
  <jsp:attribute name="quickLinks_include">
    <c:choose>
      <c:when test="${agentDetails.agentTypeDetailsForm}">
        <bs:openInSakuraUI agentType="${agentDetails.agentType}" />
      </c:when>
      <c:otherwise>
        <bs:openInSakuraUI agent="${agentDetails.agent}" />
      </c:otherwise>
    </c:choose>
  </jsp:attribute>
  <jsp:attribute name="head_include">
    <c:choose>
      <c:when test="${agentDetails.agentTypeDetailsForm}">
        <bs:redirectToSakuraUI agentType="${agentDetails.agentType}" />
        <bs:sakuraReleaseBanner agentType="${agentDetails.agentType}" />
      </c:when>
      <c:otherwise>
        <c:if test="${currentTab != 'agentLogs' || empty param.logName}">
          <bs:redirectToSakuraUI agent="${agentDetails.agent}" />
          <bs:sakuraReleaseBanner agent="${agentDetails.agent}" />
        </c:if>
      </c:otherwise>
    </c:choose>

    <bs:linkCSS>
      /css/progress.css
      /css/viewType.css
      /css/compatibilityList.css
      /css/overviewTable.css
      /css/agents.css
      /css/filePopup.css
    </bs:linkCSS>
    <bs:linkScript>
      /js/bs/runningBuilds.js
      /js/bs/testGroup.js

      /js/bs/blocks.js
      /js/bs/blockWithHandle.js

      /js/bs/agents.js
    </bs:linkScript>
    <c:if test="${serverSummary.hasSeveralAgentPools}"><c:set var="poolName">${agentDetailInfo.poolName} pool</c:set></c:if>
    <c:set var="agentName">${agentDetailInfo.caption}</c:set>
    <script type="text/javascript">
      ReactUI.setActivePageId('agents');
    </script>

  </jsp:attribute>
<jsp:attribute name="body_include">
  <bs:refreshable containerId="agentTabContent" pageUrl="${pageUrl}">
  <c:if test="${(not empty realAgentName) and agentDetailInfo.agentType}">
    <c:if test="${agentDetails.agent.details.cloudAgent}">
    <div class="successMessage">
      Agent <c:out value="${realAgentName}"/> is a cloud agent that was stopped. Displaying cloud agent image page that corresponds to the agent.
    </div>
    </c:if>
  </c:if>
  <div class="agentDetails" id="agentDetails">
    <script type="text/javascript">
      BS.Navigation.items = [
        <c:choose>
        <c:when test="${agentDetailInfo.agentType}">
        <jsp:useBean id="agentDetails" type="jetbrains.buildServer.controllers.agent.AgentTypeDetailsForm" scope="request"/>
        <c:choose>
        <c:when test="${agentDetails.agent.details.cloudAgent}">
        {title: "Cloud Agent Images", url:"<c:url value='/agents.html?tab=clouds'/>"},
        </c:when>
        <c:otherwise>
        {title: "Agents", url:"<c:url value='/agents.html'/>"},
        </c:otherwise>
        </c:choose>
        </c:when>
        <c:when test="${not agentDetailInfo.authorized}">
        {title: "Unauthorized agents", url:"<c:url value='/agents.html?unauthorized=true'/>"},
        </c:when>
        <c:when test="${not agentDetailInfo.registered}">
        {title: "Disconnected agents", url:"<c:url value='/agents.html?unregistered=true'/>"},
        </c:when>
        <c:otherwise>
        {title: "Connected agents", url:"<c:url value='/agents.html'/>"},
        </c:otherwise>
        </c:choose>
        <c:if test="${serverSummary.hasSeveralAgentPools}">
        {title: "<bs:escapeForJs text="${poolName}" forHTMLAttribute="true"/>", url:"<c:url value='/agents.html?tab=agentPools#${agentDetails.agentType.agentPool.agentPoolId}'/>"},
        </c:if>
        {title: "<bs:escapeForJs text="${agentName}" forHTMLAttribute="true"/>", url:"<c:url value='/agentDetails.html?${agentDetailInfo.urlParameters}'/>", selected:true}
      ];
      BS.Navigation.writeCompactNavigation();


      (function() {
        var paneNav = new TabbedPane();

        function initialize3dLevel(paneNav, myTabs) {
          paneNav.clearTabs();
          var baseUrl = "<c:url value='/agentDetails.html?${agentDetailInfo.urlParameters}&tab='/>";
          for(var tabCode in myTabs) {
            paneNav.addTab(tabCode, {
              caption: myTabs[tabCode].title,
              url: baseUrl + tabCode
            });
          }

          paneNav.setActiveCaption('${currentTab}');
        }

        var agentDetailsTabs = {};

        // Process plugins/tabs:
        <c:set var="selectedTabExtension" value="${null}"/>

        <c:set var="hasTabs" value="${false}"/>
        <ext:forEachTab placeId="<%=PlaceId.AGENT_DETAILS_TAB%>">
          <c:set var="hasTabs" value="${true}"/>
          // plugin ${extension.tabId}:
          agentDetailsTabs['${extension.tabId}'] = { title: '<bs:escapeForJs text="${extension.tabTitle}"/>' };
          <c:if test="${currentTab == extension.tabId}">
            <c:set var='selectedTabExtension' value="${extension}"/>
          </c:if>
        </ext:forEachTab>

        initialize3dLevel(paneNav, agentDetailsTabs);
        if (paneNav.getNumberOfTabs() > 1) {
          paneNav.showIn('tabsContainer3');
        }
      })();
    </script>
    <div class="agentsContent">
      <c:choose>
        <c:when test="${hasTabs and not empty selectedTabExtension}">
          <ext:includeExtension extension="${selectedTabExtension}"/>
        </c:when>
        <c:otherwise>No tab selected</c:otherwise>
      </c:choose>

    </div>

  </div>
  </bs:refreshable>
</jsp:attribute>
</bs:page>
