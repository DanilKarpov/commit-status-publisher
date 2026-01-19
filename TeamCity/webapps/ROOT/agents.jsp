<%@ include file="include-internal.jsp" %>
<jsp:useBean id="currentUser" type="jetbrains.buildServer.users.User" scope="request"/>
<jsp:useBean id="currentTab" scope="request" type="java.lang.String"/>
<jsp:useBean id="myCustomTab" scope="request" type="jetbrains.buildServer.web.openapi.CustomTab"/>

<c:set var="currentTabCaption" value=" > ${myCustomTab.tabTitle}"/>

<bs:page>
<jsp:attribute name="page_title">Agents${currentTabCaption}</jsp:attribute>
<jsp:attribute name="quickLinks_include">

<c:choose>
  <c:when test="${intprop:getBooleanOrTrue('teamcity.internal.agent.distribution.jdk.bundle.enabled')}">
    <a class="quickLinksControlLink toolbarItem" target="_blank" href="<c:url value='/installFullAgent.html'/>">Install Build Agents</a>
  </c:when>
  <c:otherwise>
    <a class="quickLinksControlLink toolbarItem" href='#' onclick='BS.InstallAgentsPopup.showNearElement(this); return false'>Install Build Agents</a>
  </c:otherwise>
</c:choose>
  <bs:openInSakuraUI agents="${true}" />
</jsp:attribute>
<jsp:attribute name="head_include">
  <bs:redirectToSakuraUI agents="${true}" />
  <bs:sakuraReleaseBanner agents="${true}" />

  <bs:linkCSS>
    /css/progress.css
    /css/agents.css
    /css/agents_react.css
    /css/installAgent.css
    /css/filePopup.css
  </bs:linkCSS>
  <bs:linkScript>
    /js/bs/runningBuilds.js
    /js/bs/testGroup.js

    /js/bs/blocks.js
    /js/bs/blockWithHandle.js

    /js/bs/agents.js
  </bs:linkScript>

  <script type="text/javascript">
    BS.Navigation.items = [
      {title: "Agents", selected:true}
    ];

    ReactUI.setActivePageId('agents');

  </script>
</jsp:attribute>

<jsp:attribute name="body_include">
  <%@ include file="agentsList.jsp" %>
</jsp:attribute>

</bs:page>

