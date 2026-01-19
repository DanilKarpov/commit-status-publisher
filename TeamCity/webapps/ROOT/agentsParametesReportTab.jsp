<%@ include file="include-internal.jsp"%>

<form action="#" onsubmit="return BS.AgentsParametersReport.group();">
  <div class="actionBar">
    <span class="nowrap">
      <label class="firstLabel" for="paramName" id="paramNameLabel">Parameter: </label>
      <forms:textField className="actionInput" name="paramName" noAutoComplete="true"/>
    </span>

    <input class="btn btn_mini" type="submit" value="Show Agents"/>
    <forms:saving id="reportResultLoading" className="progressRingInline"/>

    <div id="paramNameError" class="error" style="display: none;">The parameter name must be specified</div>
  </div>
</form>

<script type="text/javascript">
  BS.AgentsParametersReport.initForm();
</script>

<div id="errors"></div>

<c:import url="/agents/agentsParametersReportResult.html"/>