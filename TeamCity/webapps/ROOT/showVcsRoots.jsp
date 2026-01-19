<%@ include file="/include-internal.jsp" %>
<div class="vcsRoots">
<c:forEach items="${vcsRoots}" var="description">
  <c:out value="${description}"/><br/>
</c:forEach>
</div>