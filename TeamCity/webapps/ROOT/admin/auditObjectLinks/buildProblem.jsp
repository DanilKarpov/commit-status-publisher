<%@ page import="jetbrains.buildServer.serverSide.problems.BuildProblemInfo" %>
<%@ page import="jetbrains.buildServer.util.StringUtil" %>

<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<c:set var="buildProblem" value="${_object}"/>
<c:out value='<%=StringUtil.truncateStringValueWithDotsAtEnd(((BuildProblemInfo) pageContext.getAttribute("buildProblem")).getBuildProblemDescription(), 50)%>'/>
