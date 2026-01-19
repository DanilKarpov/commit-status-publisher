<%@ page import="jetbrains.buildServer.serverSide.SBuildServer" %>
<%@ page import="jetbrains.buildServer.serverSide.SBuildType" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags/"
%><%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin"
%><%@ taglib prefix="l" tagdir="/WEB-INF/tags/layout"
%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"
%><%@ taglib prefix="afn" uri="/WEB-INF/functions/authz"
%><%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<jsp:useBean id="buildType" scope="request" type="jetbrains.buildServer.serverSide.SBuildType"/>
<admin:editBuildTypeNavSteps settings="${buildType}"/>
<div id="buildTypeTabsContainer" class="simpleTabs clearfix"></div>
<script type="text/javascript">
  (function() {
    var tabs = new TabbedPane("buildTypeTabs");

    <c:forEach var="configStep" items="${buildConfigSteps}">
    <c:set var="tabCaption"><bs:forJs>${configStep.title}</bs:forJs></c:set>

    <c:set var="url"><admin:editBuildTypeLink step="${configStep.stepId}" buildTypeId="${buildType.externalId}" title="${configStep.title}" withoutLink="true"/></c:set>

    tabs.addTab('buildType_${configStep.stepId}', {
      caption: '${tabCaption}',
      url: '${url}'
    });
    </c:forEach>

    tabs.showIn('buildTypeTabsContainer');
  })();
</script>
