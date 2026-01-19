<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin"
%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"
%><%@ taglib prefix="afn" uri="/WEB-INF/functions/authz"
%><c:set var="vcsRoot" value="${_object}"
/><admin:vcsRootName vcsRoot="${vcsRoot}" editingScope="none" cameFromUrl="${pageUrl}"/>