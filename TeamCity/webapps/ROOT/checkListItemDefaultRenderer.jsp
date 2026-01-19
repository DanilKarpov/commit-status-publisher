<%@ include file="include-internal.jsp"%>
<label for="${checkBoxId}">
  <bs:trim maxlength="40">${checkListItem.info.name}</bs:trim>
  <c:set var="note" value="${checkListItem.info.note}"/>
  <c:if test="${not empty note}">
    <span class="checkListItemNote"><c:out value="${note}"/></span>
  </c:if>
</label>
