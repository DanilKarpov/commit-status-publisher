<%@ include file="/include-internal.jsp"%>
<c:set var="date"><bs:date pattern="dd MMM HH:mm" value="${vcsChange.vcsDate}" no_span="true"/></c:set>
<c:set var="htmlTitle"><c:out value="${vcsChange.description}"/></c:set>
<forms:option value="${vcsChange.id}" selected="${not empty selectedChange && selectedChange.id == vcsChange.id}" htmlTitle="${htmlTitle}">
  [${date}] <c:if test="${not fn:contains(vcsChange.displayVersion, date)}">(<bs:trim maxlength="15">${vcsChange.displayVersion}</bs:trim>)</c:if>
  <bs:changeCommitters modification="${vcsChange}" no_tooltip="${true}" no_avatar="${true}"/>: <bs:trim maxlength="50">${vcsChange.description}</bs:trim>
</forms:option>
