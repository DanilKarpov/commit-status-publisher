<%@ taglib prefix="tests" tagdir="/WEB-INF/tags/tests"
%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"
%><c:set var="test" value="${_object}"
/><tests:testDetailsLink testBean="${test}" hideIcon="true"><c:out value="${test.name.shortName}"/></tests:testDetailsLink>