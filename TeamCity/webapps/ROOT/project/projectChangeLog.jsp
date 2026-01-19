<%@ include file="../include-internal.jsp" %>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request" />
<jsp:useBean id="changeLogBean" type="jetbrains.buildServer.controllers.buildType.tabs.ChangeLogBean" scope="request" />

<bs:changesList
     changeLog="${changeLogBean}"
     url="/project.html?projectId=${project.externalId}&tab=projectChangeLog"
     filterUpdateUrl="/projectChangeLogTab.html?projectId=${project.externalId}"
     projectId="${project.externalId}"
     hideBuildSelectors="true"
     hideShowBuilds="true"/>