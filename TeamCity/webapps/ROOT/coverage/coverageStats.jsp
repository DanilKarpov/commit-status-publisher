<c:set var="maxStatsTypes" value="5"/>
<table class="coverageStatsTable">
  <tr>
    <c:forEach items="${coverageSummary.availableStatTypes}" var="statType">
      <c:set var="statEntry" value="${coverageSummary.statistics[statType]}"/>
      <c:set var="val"><c:out value="${statEntry.percentString}"/></c:set>
      <td class="label">${statType.displayName}</td>
      <td><span
          class="barBorder"
          <c:if test="${statEntry.covered >= 0}">
            <c:set var="covered"><fmt:formatNumber value="${statEntry.covered}" groupingUsed="false"/></c:set>
            <bs:tooltipAttrs text="${covered}/${statEntry.total}"/>
          </c:if>
        >${val}<span class="barBorderInner" style="width:${statEntry.percent}%"><span class="barBorderInnerText">${val}</span></span></span></td>
    </c:forEach>
  </tr>
  <c:if test="${not empty coverageSummary.prevBuild}">
    <tr>
      <c:forEach items="${coverageSummary.availableStatTypes}" var="statType">
        <c:set var="diff" value="${coverageSummary.statistics[statType].diff}"/>
        <c:set var="val"><c:out value="${diff.percentDiffString}"/></c:set>
        <td class="label">Diff:</td>
        <td><span class="diffValue ${diff.percentDiff < 0 ? 'red' : (diff.percentDiff > 0 ? 'green' : '')}">${diff.percentDiff > 0 ? '+' : ''}${val}</span></td>
      </c:forEach>
    </tr>
  </c:if>
</table>

<c:if test="${not empty coverageSummary.coverageReportTabId}">
  <div><bs:_viewLog build="${coverageSummary.build}" tab="${coverageSummary.coverageReportTabId}">View report &raquo;</bs:_viewLog></div>
</c:if>