<%@ include file="include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean id="buildType" type="jetbrains.buildServer.serverSide.SBuildType" scope="request"/>
<jsp:useBean id="systemProblems" scope="request" type="java.util.Collection<jetbrains.buildServer.controllers.changes.ProblemBean>"/>

<bs:showSystemProblems projectId="${buildType.projectId}" systemProblems="${systemProblems}"/>
