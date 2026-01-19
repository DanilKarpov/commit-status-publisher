<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="ext" tagdir="/WEB-INF/tags/ext" %>
<%@ taglib prefix="authz" tagdir="/WEB-INF/tags/authz" %>
<%@ taglib prefix="problems" tagdir="/WEB-INF/tags/problems" %>
<%@ taglib prefix="resp" tagdir="/WEB-INF/tags/responsible" %>

<jsp:useBean id="buildProblem" type="jetbrains.buildServer.serverSide.problems.BuildProblem" scope="request"/>

<c:set var="problemId" value='<%=String.format("%s_%s", buildProblem.getId(), buildProblem.getBuildPromotion().getId())%>'/>
<c:set var="placeId" value="<%=PlaceId.BUILD_RESULTS_BUILD_PROBLEM%>"/>
<ext:includeExtensions placeId="${placeId}" includeReactExtensions="true"/>
