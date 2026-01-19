<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<c:set var="itemCategory" value="${_object}"/>
<c:out value='of category'/> <strong><c:out value="${itemCategory.name}"/></strong>