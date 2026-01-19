<%@ page import="jetbrains.buildServer.serverSide.SBuildServer" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin"
  %><%@ taglib prefix="l" tagdir="/WEB-INF/tags/layout"
  %><%@ taglib prefix="bs" tagdir="/WEB-INF/tags"
  %><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"
  %>
<jsp:useBean id="template" scope="request" type="jetbrains.buildServer.serverSide.BuildTypeTemplate"/>
<admin:editBuildTypeNavSteps settings="${template}"/>
<div id="templateTabsContainer" class="simpleTabs clearfix"></div>
<script type="text/javascript">
  (function() {
    var tabs = new TabbedPane("templateTabs");

    <c:forEach var="configStep" items="${buildConfigSteps}">
    <c:set var="tabCaption"><bs:forJs>${configStep.title}</bs:forJs></c:set>

    <c:set var="url"><admin:editTemplateLink step="${configStep.stepId}" templateId="${template.externalId}" title="${configStep.title}" withoutLink="true"/></c:set>

    tabs.addTab('${configStep.stepId}', {
      caption: '${tabCaption}',
      url: '${url}'
    });
    </c:forEach>

    tabs.showIn('templateTabsContainer');
  })();
</script>
