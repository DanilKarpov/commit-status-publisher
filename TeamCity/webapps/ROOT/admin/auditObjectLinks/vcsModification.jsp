<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"
%><%@ taglib prefix="bs" tagdir="/WEB-INF/tags"
%><%@ taglib prefix="afn" uri="/WEB-INF/functions/authz"
%><c:set var="modification" value="${_object}"
/><bs:modificationLink modification="${modification}"
                       tab="vcsModificationFiles"><c:out value="${modification.displayVersion}"/></bs:modificationLink>