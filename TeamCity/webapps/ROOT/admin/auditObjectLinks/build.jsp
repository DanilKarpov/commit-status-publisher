<%@ taglib prefix="bs" tagdir="/WEB-INF/tags"
%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"
%><c:set var="build" value="${_object}"
/><c:set var="branch" value="${build.branch}"
/><bs:buildLinkFull build="${build}"/><c:if test="${build.personal}"> (personal)</c:if
 ><c:if test="${not empty branch}"> in branch <bs:branchLink branch="${branch}" build="${build}" plain="true"/></c:if>