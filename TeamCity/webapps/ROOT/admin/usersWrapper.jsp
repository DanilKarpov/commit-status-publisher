<%--
A workaround for POST requests. See TW-19743
--%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"
%><c:if test="${not empty userListForm}"
    ><jsp:include page="users.jsp"
/></c:if>
