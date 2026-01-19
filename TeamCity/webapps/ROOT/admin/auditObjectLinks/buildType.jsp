<%@ taglib prefix="bs" tagdir="/WEB-INF/tags"
%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"
%><c:set var="buildType" value="${_object}"
/><bs:buildTypeLinkFull buildType="${buildType}"
/><c:if test="${buildType.personal}"> (personal)</c:if>