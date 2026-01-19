<%@include file="/include-internal.jsp"%>

<div>
  The ${projectId} project has multiple <a href="${contextPath}/admin/editProject.html?projectId=${projectId}&tab=issueTrackers">Issue trackers</a> with identical issue ID patterns: <br />

  <ul>
    <c:forEach items="${repeatingPatterns}" var="entry">
      <li>
        Pattern <c:out value='${entry.key}'/> is configured for Issue trackers:

        <c:forEach items="${entry.value}" var="tracker" varStatus="loop">
          <c:out value='${tracker}'/>${not loop.last ? ', ' : ''}
        </c:forEach>
      </li>
    </c:forEach>
  </ul>
  This may lead to unpredicted issue handling results. Remove duplicate trackers or modify their patterns.
</div>