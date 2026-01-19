<%@ taglib prefix="bs" tagdir="/WEB-INF/tags"
%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"
%><c:set var="promotion" value="${_object}"
/><c:set var="branch" value="${promotion.branch}"
/><c:set var="build" value="${promotion.associatedBuild}"
/><c:set var="buildType" value="${promotion.buildType}"
/><c:choose
><c:when test="${build != null}"><bs:buildLinkFull build="${build}"/></c:when
><c:when test="${buildType != null}">of <bs:buildTypeLinkFull buildType="${buildType}" branch="${not empty build ? build.branch : null}"/></c:when
><c:otherwise>of unknown build configuration</c:otherwise
></c:choose><c:if test="${promotion.personal}"> (personal)</c:if
><c:if test="${not empty branch}"> in branch <bs:branchLink branch="${branch}" buildPromotion="${promotion}" plain="true"/></c:if>