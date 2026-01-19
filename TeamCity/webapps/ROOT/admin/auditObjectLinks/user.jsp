<%@ taglib prefix="bs" tagdir="/WEB-INF/tags"
%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"
%><c:set var="user" value="${_object}"/><bs:userLink user="${user}"><c:out value="${user.extendedName}"/></bs:userLink>